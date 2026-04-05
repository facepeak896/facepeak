from typing import Dict, List, Any


def run_ai_chatbot(context: Dict[str, Any]) -> Dict:
    """
    FacePeak AI Chatbot – V2
    Read-only, context-aware assistant.
    Explains results, highlights strengths, and suggests priorities.
    """

    # ---------- VALIDATION ----------
    if not isinstance(context, dict) or not context:
        return {
            "status": "error",
            "error": "EMPTY_CONTEXT",
            "message": "No analysis context provided for chatbot."
        }

    try:
        # ---------- ASSISTANT PROFILE ----------
        assistant = {
            "name": "FacePeak AI",
            "role": "Facial Analysis Assistant",
            "tone": "Supportive, neutral, educational",
            "version": "v2"
        }

        # ---------- EXTRACT SCORES SAFELY ----------
        psl_score = context.get("psl", {}).get("psl_score")
        appeal_score = context.get("appeal", {}).get("presentation_score")
        hair_score = context.get("hair", {}).get("overall_score")
        symmetry_score = context.get("symmetry", {}).get("overall_score")

        scores = {
            "Structure (PSL)": psl_score,
            "Presentation (Appeal)": appeal_score,
            "Hair": hair_score,
            "Symmetry": symmetry_score,
        }

        # keep only valid numbers
        scores = {k: v for k, v in scores.items() if isinstance(v, (int, float))}

        # ---------- STRENGTHS / IMPROVEMENTS ----------
        strengths: List[str] = []
        improvements: List[str] = []

        for name, score in scores.items():
            if score >= 7.5:
                strengths.append(name)
            elif score < 6.5:
                improvements.append(name)

        # ---------- PRIORITY LOGIC (TOP 3) ----------
        priority_order = sorted(
            scores.items(),
            key=lambda x: x[1]
        )

        top_priorities = [
            {
                "area": name,
                "score": round(score, 2),
                "reason": "This area currently contributes less compared to others and may benefit most from attention."
            }
            for name, score in priority_order[:3]
        ]

        # ---------- EXPLANATIONS ----------
        explanations = {
            "Structure (PSL)": (
                "Structural balance reflects bone relationships and proportions. "
                "These change slowly over time and are less affected by daily factors."
            ),
            "Presentation (Appeal)": (
                "Presentation reflects surface-level factors like skin condition, grooming, and lighting. "
                "It can change relatively quickly with habits and care."
            ),
            "Hair": (
                "Hair influences framing and first impressions. "
                "Styling, grooming, and maintenance can significantly affect this area."
            ),
            "Symmetry": (
                "Symmetry describes left-right balance. "
                "Minor asymmetries are completely normal and expected."
            ),
        }

        # ---------- SUGGESTED QUESTIONS ----------
        suggested_questions = [
            "What should I focus on improving first?",
            "Which results can change the fastest?",
            "How much does grooming affect my overall look?",
            "How important is symmetry compared to other factors?",
            "What improvements are realistic without invasive changes?"
        ]

        # ---------- SAFETY ----------
        safety = {
            "rules": [
                "No medical or surgical advice",
                "No negative or judgmental language",
                "Educational guidance only",
                "Focus on healthy, realistic improvements"
            ],
            "restricted_topics": [
                "Medical treatments",
                "Plastic surgery recommendations",
                "Mental health diagnosis",
                "Comparison to other people"
            ]
        }

        # ---------- FINAL RESPONSE ----------
        return {
            "status": "success",
            "assistant": assistant,
            "summary": {
                "strengths": strengths or ["No dominant strengths identified in this capture"],
                "improvement_areas": improvements or ["No major weak areas detected"],
            },
            "priorities": top_priorities,
            "explanations": {
                k: explanations.get(k)
                for k in scores.keys()
            },
            "suggested_questions": suggested_questions,
            "safety": safety,
            "disclaimer": (
                "FacePeak AI provides educational and informational guidance only. "
                "Results are based on visual analysis of a single image and do not "
                "define personal value or attractiveness."
            )
        }

    except Exception as e:
        return {
            "status": "error",
            "error": "CHATBOT_V2_FAILED",
            "message": str(e)
        }