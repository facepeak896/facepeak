from typing import Dict, List, Tuple


METRICS = [
    "Jawline",
    "Cheekbones",
    "Eyes",
    "Eyebrows",
    "Nose",
    "Lips",
    "Face shape",
    "Hair framing",
]


# -------------------------------------------------
# METRIC DESCRIPTIONS (NEW)
# -------------------------------------------------

METRIC_DESCRIPTIONS = {
    "Jawline": "Your jawline contributes to lower-face definition and overall facial structure.",
    "Cheekbones": "Your cheekbones influence mid-face depth and structural balance.",
    "Eyes": "Eye shape and spacing affect upper-face harmony and expression.",
    "Eyebrows": "Eyebrows frame the eyes and influence facial expression.",
    "Nose": "Nose structure affects the balance of the central face.",
    "Lips": "Lip structure contributes to lower-face harmony and proportion.",
    "Face shape": "Face shape determines overall facial proportions and balance.",
    "Hair framing": "Hair framing influences how facial structure is visually perceived.",
}


def attributes_to_psl_signals(attrs: Dict[str, bool]) -> Dict[str, float]:

    scores = {m: 0.0 for m in METRICS}

    # -------------------
    # JAWLINE
    # -------------------

    if attrs.get("Strong_Jawline"):
        scores["Jawline"] += 0.9

    if attrs.get("Double_Chin"):
        scores["Jawline"] -= 0.8

    # -------------------
    # CHEEKBONES
    # -------------------

    if attrs.get("High_Cheekbones"):
        scores["Cheekbones"] += 0.8

    if attrs.get("Chubby"):
        scores["Cheekbones"] -= 0.5

    # -------------------
    # EYES
    # -------------------

    if attrs.get("Big_Eyes"):
        scores["Eyes"] += 0.7

    if attrs.get("Narrow_Eyes"):
        scores["Eyes"] -= 0.6

    if attrs.get("Bags_Under_Eyes"):
        scores["Eyes"] -= 0.6

    # -------------------
    # EYEBROWS
    # -------------------

    if attrs.get("Arched_Eyebrows"):
        scores["Eyebrows"] += 0.5

    if attrs.get("Bushy_Eyebrows"):
        scores["Eyebrows"] += 0.6

    # -------------------
    # NOSE
    # -------------------

    if attrs.get("Straight_Nose"):
        scores["Nose"] += 0.6

    if attrs.get("Big_Nose"):
        scores["Nose"] -= 0.6

    if attrs.get("Pointy_Nose"):
        scores["Nose"] += 0.4

    # -------------------
    # LIPS
    # -------------------

    if attrs.get("Big_Lips"):
        scores["Lips"] += 0.4

    if attrs.get("Thin_Lips"):
        scores["Lips"] -= 0.4

    # -------------------
    # FACE SHAPE
    # -------------------

    if attrs.get("Oval_Face"):
        scores["Face shape"] += 0.7

    if attrs.get("Square_Face"):
        scores["Face shape"] += 0.6

    if attrs.get("Round_Face"):
        scores["Face shape"] -= 0.5

    # -------------------
    # HAIR FRAMING
    # -------------------

    if attrs.get("Wavy_Hair"):
        scores["Hair framing"] += 0.3

    if attrs.get("Bangs"):
        scores["Hair framing"] += 0.3

    if attrs.get("Receding_Hairline"):
        scores["Hair framing"] -= 0.4

    if attrs.get("Bald"):
        scores["Hair framing"] -= 0.3

    return scores


def pick_psl_limits_strengths(scores: Dict[str, float], score: int):

    items = list(scores.items())

    # sortiraj od najboljeg prema najgorem
    items.sort(key=lambda x: x[1], reverse=True)

    score = max(1, min(score, 8))

    # -------------------
    # SCORE TABLICA
    # -------------------

    if score == 1:
        strength_count = 1
        limit_count = 5

    elif score == 2:
        strength_count = 2
        limit_count = 4

    elif score == 3:
        strength_count = 3
        limit_count = 3

    elif score == 4:
        strength_count = 4
        limit_count = 2

    elif score == 5:
        strength_count = 5
        limit_count = 1

    else:  # 6+
        strength_count = 6
        limit_count = 0

    # -------------------
    # STRENGTHS
    # -------------------

    strengths = [name for name, _ in items[:strength_count]]

    # -------------------
    # LIMITS
    # -------------------

    limits = []

    if limit_count > 0:

        reversed_items = list(reversed(items))

        for name, _ in reversed_items:

            if name in strengths:
                continue

            limits.append(name)

            if len(limits) >= limit_count:
                break

    return strengths, limits