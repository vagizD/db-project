from ab_test_tools import preprocess_request, verify, score, pass_business_logic
from datetime import datetime, timedelta
from connections import (
    insert_history_requests,
    insert_history_decisions,
    insert_history_verification_results,
    insert_history_credit_history,
    is_blacklist
)


def cred_routing(request):
    request = preprocess_request(request)
    request_id = insert_history_requests(request)
    print(f"Processing request {request_id}...")
    request['request_id'] = request_id

    if is_blacklist(request):
        request["decision_reason_id"] = 1

        insert_history_decisions(request)
        return

    request['credit_history_xml'] = 'DATA ' + str(request_id)
    insert_history_credit_history(request)

    request = verify(request)
    insert_history_verification_results(request)

    if not request["is_verified"]:
        request["decision_reason_id"] = 2

        insert_history_decisions(request)
        return

    request = score(request)

    if not request["is_approved"]:
        request["decision_reason_id"] = 3

        insert_history_decisions(request)
        return

    if not pass_business_logic(request):
        request["decision_reason_id"] = 4
        request["is_approved"] = 0

        insert_history_decisions(request)
        return

    request["approved_sum"] = request["request_sum"]
    request["max_cred_end_date"] = datetime.today() + timedelta(days=30*6)
    request["decision_reason_id"] = 5
    insert_history_decisions(request)
    return
