from Backend.ai.psl_adapter import run_psl_adapter
from Backend.ai.attr_adapter import predict_attributes
from Backend.ai.sl_mapper import (
    attributes_to_psl_signals,
    pick_psl_limits_strengths,
    METRIC_DESCRIPTIONS,   # ✅ NEW
)


def analyze_face(extractor_output):

    print("\n==============================")
    print("ANALYZE_FACE START")
    print("==============================")

    # -----------------------------------
    # 1️⃣ PSL SCORE
    # -----------------------------------

    psl_result = run_psl_adapter(extractor_output)

    print("PSL RESULT:", psl_result)

    if not isinstance(psl_result, dict):
        return {"status": "error", "reason": "INVALID_PSL_RESULT"}

    if psl_result.get("status") != "success":
        return psl_result

    score = psl_result.get("psl", {}).get("psl_score")

    print("PSL SCORE:", score)

    # -----------------------------------
    # 2️⃣ EMBEDDING
    # -----------------------------------

    embedding = extractor_output.get("embedding")

    print("EMBEDDING EXISTS:", embedding is not None)

    if embedding is None:
        return {"status": "error", "reason": "NO_EMBEDDING"}

    # -----------------------------------
    # 3️⃣ ATTRIBUTES
    # -----------------------------------

    attrs = predict_attributes(embedding)

    print("ATTRIBUTES:", attrs)

    if attrs is None:
        return {"status": "error", "reason": "ATTRIBUTE_MODEL_FAILED"}

    # -----------------------------------
    # 4️⃣ PSL SIGNALS
    # -----------------------------------

    signals = attributes_to_psl_signals(attrs)

    print("SIGNALS:", signals)
    print("SIGNAL COUNT:", len(signals))

    strengths, limits = pick_psl_limits_strengths(signals, score)

    print("STRENGTHS:", strengths)
    print("LIMITS:", limits)

    # -----------------------------------
    # 5️⃣ FINAL RESPONSE
    # -----------------------------------

    result = {
        "status": "success",
        "psl": {
            "psl_score": score
        },
        "strengths": strengths,
        "limits": limits,
        "metric_cards": METRIC_DESCRIPTIONS   # ✅ NEW
    }

    print("FINAL RESULT:", result)
    print("==============================\n")

    return result