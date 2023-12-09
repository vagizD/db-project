from datetime import date, datetime

from insert import (insert_blacklist, insert_clients, insert_decision_reasons,
                    insert_history_credit_history, insert_history_decisions,
                    insert_history_payments, insert_history_requests,
                    insert_history_verification_results, insert_models,
                    insert_orders, insert_overdue_orders)
from models import (ACTIVE_SCORING_MODEL_ID, ACTIVE_VERIFICATION_MODEL_ID,
                    MODELS)

REQUEST = {
    "first_name": "FIRST_NAME",
    "last_name": "LAST_NAME",
    "middle_name": "MIDDLE_NAME",
    "request_sum": 10000,
    "passport": "123456789",
    "passport_issued_by": "MIA",
    "passport_expiring_date": date(2030, 1, 1),
    "email": "test@test.test",
    "phone_number": "90055551122",
    "address": "Pushkin st., Saint-Petersburg",
}


def preprocess_request(request):
    request["requested_at"] = datetime.now()
    request["is_under"] = 0
    return request


def is_blacklist(request):
    return False


def verify(request):
    model = MODELS[ACTIVE_VERIFICATION_MODEL_ID]
    request["verification_score"] = model["score_method"](request)
    request["is_verified"] = request["verification_score"] >= model["threshold"]
    request["verified_at"] = datetime.now()
    request["verification_model_id"] = ACTIVE_VERIFICATION_MODEL_ID

    return request


def scoring(request):
    model = MODELS[ACTIVE_SCORING_MODEL_ID]
    request["scoring_score"] = model["score_method"](request)
    request["is_approved"] = request["credit_score"] >= model["threshold"]
    request["scored_at"] = datetime.now()
    request["scoring_model_id"] = ACTIVE_SCORING_MODEL_ID

    return request


def pass_business_logic(request):
    if request["first_name"] == "Василий":
        return False

    return True


def cred_routing(request):
    request = preprocess_request(request)
    insert_history_requests(request)

    if is_blacklist(request):
        request["decision_reason_id"] = 0

        insert_history_decisions(request)
        return

    request = verify(request)
    insert_history_verification_results(request)

    if not request["is_verified"]:
        request["decision_reason_id"] = 1

        insert_history_decisions(request)
        return

    request = scoring(request)

    if not request["is_approved"]:
        request["decision_reason_id"] = 2

        insert_history_decisions(request)
        return

    if not pass_business_logic(request):
        request["decision_reason_id"] = 3
        request["is_approved"] = 0

        insert_history_decisions(request)
        return
