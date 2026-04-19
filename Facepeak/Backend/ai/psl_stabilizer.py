import numpy as np


def _clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def _expected_score(probs: np.ndarray) -> float:
    classes = np.arange(1, 9, dtype=np.float32)
    return float(np.sum(probs * classes))


def _score_to_tier(score: float) -> int:
    return int(round(_clamp(score, 1.0, 8.0)))


def _confidence_weight(conf: float) -> float:
    # koliko vjerujemo novom raw outputu
    if conf >= 0.85:
        return 0.68
    if conf >= 0.75:
        return 0.56
    if conf >= 0.65:
        return 0.44
    if conf >= 0.55:
        return 0.34
    return 0.22


def _borderline_bonus(raw_expected: float, conf: float, previous_score: float | None) -> float:
    bonus = 0.0
    frac = raw_expected - np.floor(raw_expected)

    # jači push prema gore kad je blizu višeg tiera
    if frac >= 0.82:
        bonus += 0.18
    elif frac >= 0.72:
        bonus += 0.13
    elif frac >= 0.62:
        bonus += 0.09
    elif frac >= 0.54:
        bonus += 0.05

    # history bonus
    if previous_score is not None:
        if previous_score >= 4.0:
            bonus += 0.08
        elif previous_score >= 3.0:
            bonus += 0.04

    # nizak confidence smanjuje bonus, ali ne ubija stabilnost
    if conf < 0.35:
        bonus *= 0.20
    elif conf < 0.45:
        bonus *= 0.40
    elif conf < 0.55:
        bonus *= 0.65
    elif conf < 0.65:
        bonus *= 0.82

    return bonus


def _apply_hysteresis(stable_score: float, previous_score: float | None) -> float:
    if previous_score is None:
        return stable_score

    prev_tier = _score_to_tier(previous_score)
    new_tier = _score_to_tier(stable_score)

    # jako težak downgrade
    if new_tier < prev_tier:
        # skoro uvijek drži isti tier ako nije baš jasno pao
        if stable_score >= (prev_tier - 0.55):
            return max(stable_score, prev_tier - 0.04)

        # i kad pada, pad je mekan
        if stable_score >= (prev_tier - 0.80):
            return max(stable_score, prev_tier - 0.16)

    # upgrade je lakši
    if new_tier > prev_tier:
        if stable_score < (prev_tier + 0.14):
            return min(stable_score, prev_tier + 0.10)

    return stable_score


def stabilize_psl(
    probs: np.ndarray,
    raw_pred: int,
    raw_confidence: float,
    previous_score: float | None = None,
):
    probs = np.asarray(probs, dtype=np.float32).reshape(-1)
    probs = probs / max(float(np.sum(probs)), 1e-8)

    raw_expected = _expected_score(probs)

    print("\n🧩 PSL STABILIZER")
    print("raw_pred:", raw_pred)
    print("raw_confidence:", round(raw_confidence, 3))
    print("raw_expected:", round(raw_expected, 3))
    print("previous_score:", previous_score)

    # strong anchor blend
    if previous_score is not None:
        w_raw = _confidence_weight(raw_confidence)
        w_prev = 1.0 - w_raw
        blended = (raw_expected * w_raw) + (float(previous_score) * w_prev)
    else:
        blended = raw_expected

    bonus = _borderline_bonus(
        raw_expected=raw_expected,
        conf=raw_confidence,
        previous_score=previous_score,
    )

    boosted = blended + bonus
    stable_score = _apply_hysteresis(boosted, previous_score)
    stable_score = _clamp(stable_score, 1.0, 8.0)
    stable_tier = _score_to_tier(stable_score)

    print("blended:", round(blended, 3))
    print("bonus:", round(bonus, 3))
    print("stable_score:", round(stable_score, 3))
    print("stable_tier:", stable_tier)

    return {
        "stable_score_float": round(stable_score, 3),
        "stable_score_int": stable_tier,
        "confidence": round(raw_confidence, 3),
        "raw_expected": round(raw_expected, 3),
        "bonus_applied": round(bonus, 3),
    }