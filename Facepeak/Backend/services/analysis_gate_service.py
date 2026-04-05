class AnalysisGateService:
    def __init__(self, selection_service, reward_service):
        self.selection = selection_service
        self.reward = reward_service

    def can_run_analysis(self, subject_id: str, analysis_type: str):
        sel = self.selection.get(subject_id)

        # ako postoji aktivna selekcija
        if sel["active"] and sel["source"] != analysis_type:
            return {
                "allowed": False,
                "reason": "OTHER_ANALYSIS_SELECTED",
                "remaining_seconds": sel["remaining_seconds"],
            }

        # ako nema selekcije → treba reward
        if not self.reward.can_watch_ad(subject_id):
            return {
                "allowed": False,
                "reason": "REWARD_LIMIT_REACHED",
            }

        return {
            "allowed": True
        }