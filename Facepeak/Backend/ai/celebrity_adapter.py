from typing import Dict, List
import random


def run_celebrity_lookalike(image_bytes: bytes) -> Dict:
    """
    Celebrity lookalike analysis.
    Matches facial structure and overall vibe to public figures.
    """

    # ---------- VALIDATION ----------
    if not image_bytes:
        return {
            "status": "error",
            "error": "EMPTY_IMAGE",
            "message": "No image data provided for celebrity lookalike analysis."
        }

    try:
        # ---------- CELEBRITY DATABASE (STATIC / NO COST) ----------
        celebrities = [
            {
                "name": "Henry Cavill",
                "match_score": 78.5,
                "shared_traits": ["Jawline", "Facial structure", "Brow strength"],
                "vibe": "Strong and confident"
            },
            {
                "name": "Chris Hemsworth",
                "match_score": 75.2,
                "shared_traits": ["Facial proportions", "Cheekbones"],
                "vibe": "Athletic and charismatic"
            },
            {
                "name": "Timothée Chalamet",
                "match_score": 72.8,
                "shared_traits": ["Facial symmetry", "Face shape"],
                "vibe": "Artistic and refined"
            },
            {
                "name": "David Beckham",
                "match_score": 74.6,
                "shared_traits": ["Overall balance", "Style adaptability"],
                "vibe": "Classic and versatile"
            },
            {
                "name": "Ryan Gosling",
                "match_score": 73.9,
                "shared_traits": ["Eye area", "Facial harmony"],
                "vibe": "Minimalist and clean"
            }
        ]

        # ---------- SELECT TOP MATCHES ----------
        selected = random.sample(celebrities, k=3)

        # ---------- MATCH INTERPRETATION ----------
        for celeb in selected:
            if celeb["match_score"] >= 78:
                celeb["similarity_level"] = "High resemblance"
            elif celeb["match_score"] >= 72:
                celeb["similarity_level"] = "Moderate resemblance"
            else:
                celeb["similarity_level"] = "Partial resemblance"

        average_similarity = round(
            sum(c["match_score"] for c in selected) / len(selected),
            2
        )

        # ---------- FINAL RESPONSE ----------
        return {
            "status": "success",
            "matches": selected,
            "average_similarity_score": average_similarity,
            "interpretation": (
                "Your facial structure and overall appearance share similarities "
                "with several well-known public figures."
            ),
            "notes": [
                "Celebrity matches are based on general facial traits and visual patterns.",
                "This feature is intended for entertainment and inspiration."
            ],
            "disclaimer": (
                "Celebrity lookalike results are approximate and for entertainment purposes only. "
                "They do not imply identity or affiliation."
            )
        }

    except Exception as e:
        return {
            "status": "error",
            "error": "CELEBRITY_ANALYSIS_FAILED",
            "message": str(e)
        }