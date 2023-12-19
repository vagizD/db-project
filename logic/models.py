import numpy as np

ACTIVE_VERIFICATION_MODEL_ID = 1
ACTIVE_SCORING_MODEL_ID = 2


MODELS = {
    1: {
        "threshold": 1 - 0.85,
        "scoring_method": lambda x: np.random.uniform(0, 1),
        "model_type": "verification",
    },
    2: {
        "threshold": 1 - 0.80,
        "scoring_method": lambda x: np.random.uniform(0, 1),
        "model_type": "scoring",
    },
}
