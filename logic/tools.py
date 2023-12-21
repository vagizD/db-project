from datetime import datetime
from models import get_model_id, MODELS


def preprocess_request(request):
    request["requested_at"] = datetime.now()
    request["is_under"] = False
    request["is_approved"] = -1
    return request


def verify(request):
    active_model_id = get_model_id("verification")
    model = MODELS[active_model_id]
    request["verification_model_score"] = model["predict_proba"](request)
    request["is_verified"] = request["verification_model_score"] >= model["threshold"]
    request["verified_at"] = datetime.now()
    request["verification_model_id"] = active_model_id

    return request


def score(request):
    active_model_id = get_model_id("scoring")
    model = MODELS[active_model_id]
    request["scoring_model_score"] = model["predict_proba"](request)
    request["is_approved"] = request["scoring_model_score"] >= model["threshold"]
    request["scored_at"] = datetime.now()
    request["scoring_model_id"] = active_model_id

    return request


def pass_business_logic(request):
    if request["first_name"] == "Василий":
        return False

    return True
