from flask import Flask, request, jsonify
from app.api.pooling import Rider, evaluate as evaluate_pool_logic

app = Flask(__name__)

@app.route("/")
def read_root():
    return jsonify({"service": "Vectra ML Service", "status": "ok"})

@app.route("/evaluate-pool", methods=["POST"])
def evaluate_pool():
    data = request.json
    riders_data = data.get("riders", [])
    
    riders = []
    for r in riders_data:
        riders.append(Rider(id=r["id"], lat=r["lat"], lon=r["lon"]))
        
    result = evaluate_pool_logic(riders)
    return jsonify(result)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
