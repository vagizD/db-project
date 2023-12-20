import numpy as np
from typing import Literal


TRAFFIC_LOAD = {
    "scoring": {
        2: 0.5,
        4: 0.5
    },
    "verification": {
        1: 0.5,
        3: 0.5
    }
}


MODELS = {
    1: {
        "threshold": 1 - 0.841,
        "predict_proba": lambda x: round(np.random.uniform(0, 1), 3),
        "model_type": "verification",
    },
    2: {
        "threshold": 1 - 0.789,
        "predict_proba": lambda x: round(np.random.uniform(0, 1), 3),
        "model_type": "scoring",
    },
    3: {
        "threshold": 1 - 0.822,
        "predict_proba": lambda x: round(np.random.uniform(0, 1), 3),
        "model_type": "verification",
    },
    4: {
        "threshold": 1 - 0.705,
        "predict_proba": lambda x: round(np.random.uniform(0, 1), 3),
        "model_type": "scoring",
    },
}


def get_model_id(model_type: Literal["scoring", "verification"]):
    models_dict = TRAFFIC_LOAD[model_type]
    models_ids = list(models_dict.keys())
    models_traffics = list(models_dict.values())
    return int(np.random.choice(models_ids, p=models_traffics))
