from datetime import datetime, date
from models import (ACTIVE_SCORING_MODEL_ID, ACTIVE_VERIFICATION_MODEL_ID,
                    MODELS)
from psycopg2 import connect


class CreditRouting:
    def create_db(self):
        with open('../environment/init-db/01-create.sql', encoding='utf-8') as f:
            create = f.read()
        self.cursor.execute(create)

    def __init__(self, db, user, password):
        self.db = db
        self.user = user
        self.password = password
        self.cn = connect(dbname=self.db, user=self.user, password=self.password, port="5432")
        self.cursor = self.cn.cursor()
        self.create_db()

    def connect_to_db(self):
        self.cn = connect(dbname=self.db, user=self.user, password=self, port="5432")
        self.cursor = self.cn.cursor()

    def preprocess_request(self, request):
        request["request_at"] = datetime.today()
        return request

    def is_blacklist(self, request):
        self.cursor.execute(
            f"select client_id from blacklist where client_id = '{request['passport']}';")
        return self.cursor.fetchone() is not None

    def verify(self, request):
        model = MODELS[ACTIVE_VERIFICATION_MODEL_ID]
        request["verification_score"] = model["scoring_method"](request)
        request["is_verified"] = request["verification_score"] >= model["threshold"]
        request["verified_at"] = datetime.now()
        request["verification_model_id"] = ACTIVE_VERIFICATION_MODEL_ID
        return request

    def scoring(self, request):
        model = MODELS[ACTIVE_SCORING_MODEL_ID]
        request["credit_score"] = model["scoring_method"](request)
        request["is_approved"] = request["credit_score"] >= model["threshold"]
        request["scored_at"] = datetime.now()
        request["scoring_model_id"] = ACTIVE_SCORING_MODEL_ID
        return request

    def pass_business_logic(self, request):
        if request["first_name"] == "Василий":
            return False
        return True

    def cred_routing(self, request):
        request = self.preprocess_request(request)
        request = self.insert_history_requests(request)

        if self.is_blacklist(request):
            request["decision_reason_id"] = 0
            self.insert_history_decisions(request)
            return

        request = self.verify(request)
        self.insert_history_verification_results(request)

        if not request["is_verified"]:
            request["decision_reason_id"] = 1
            self.insert_history_decisions(request)
            return

        request = self.scoring(request)

        if not request["is_approved"]:
            request["decision_reason_id"] = 2
            self.insert_history_decisions(request)
            return

        if not self.pass_business_logic(request):
            request["decision_reason_id"] = 3
            request["is_approved"] = 0
            self.insert_history_decisions(request)
            return

        request["decision_reason_id"] = 4
        self.insert_history_requests(request)

    @staticmethod
    def preprocess(value):
        if type(value) != datetime:
            return value
        return value.strftime("%Y-%m-%d %H:%M:%S")

    def get_insert(self, tbl_name, request, fields):
        values = []
        for field in fields:
            if field in request.keys():
                values.append(CreditRouting.preprocess(request[field]))
            elif tbl_name == "history_decisions":
                if field == "model_score" and "credit_score" in request.keys():
                    values.append(CreditRouting.preprocess(request["credit_score"]))
                elif field == "model_id" and "scoring_model_id" in request.keys():
                    values.append(CreditRouting.preprocess(request["scoring_model_id"]))
                else:
                    values.append(None)
            elif tbl_name == "history_verification_results":
                if field == "score" and "verification_score" in request.keys():
                    values.append(CreditRouting.preprocess(request["verification_score"]))
                elif field == "model_id" and "verification_model_id" in request.keys():
                    values.append(CreditRouting.preprocess(request["verification_model_id"]))
                else:
                    values.append(None)
            else:
                values.append(None)
        insert = f"INSERT into {tbl_name}({', '.join(fields)}) values {tuple(values)} returning request_id;"
        return insert

    def insert_history_requests(self, request):
        fields = {
            "request_at", "request_sum", "first_name", "last_name", "middle_name",
            "birth_date", "passport", "passport_issued_by", "email", "phone_number", "country",
            "city", "address"
        }
        insert = self.get_insert("history_requests", request, fields)
        print(insert)

        self.cursor.execute(insert)
        request["request_id"] = self.cursor.fetchone()[0]
        print(request["request_id"])
        return request

    def insert_history_decisions(self, request):
        startDate = datetime.now()
        request["max_cred_end_date"] = datetime(startDate.year + 1, startDate.month, startDate.day)
        fields = {"model_id", "model_score", "scored_at", "approved_sum",
                  "is_under", "max_cred_end_date"}
        insert = self.get_insert("history_decisions", request, fields)
        print(insert)
        self.cursor.execute(insert)

    def insert_history_verification_results(self, request):
        fields = {"request_id", "model_id", "score", "is_verified", "verified_at"}
        insert = self.get_insert("history_verification_results", request, fields)
        print(insert)
        self.cursor.execute(insert)

    def check(self, tbl_name):
        check = f"SELECT * FROM {tbl_name};"
        self.cursor.execute(check)
        print(self.cursor.fetchall())


REQUEST = {
    "request_sum": 1000,
    "first_name": "Vasya",
    "last_name": "Pirogov",
    "middle_name": "-",
    "birth_date": "1990-01-01",
    "passport": "1234567891",
    "passport_issued_by": "МФЦ Алтайского Края",
    "email": "ivanov@yandex.ru",
    "phone_number": "72663767143",
    "country": "Лалаленд",
    "city": "КАЗАХСТАН",
    "address": "ул. Примерная, д. 3"
}

ex = CreditRouting("postgres", "postgres", "1234")
ex.check("history_requests")
ex.cred_routing(REQUEST)
ex.check("history_requests")
