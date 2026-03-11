"""
Pooling evaluation API.

POST /evaluate-pool
  Body: { vehicle_type: str, riders: [{ id, lat, lon }] }
  Response: { isValid, score, sequence, detourOk }

Algorithm:
  1. Build a cost matrix using Haversine distance.
  2. Use a nearest-neighbour TSP heuristic to find pickup sequence.
  3. Calculate total pooled route length vs. sum of solo routes.
  4. Accept if pooled route is within MAX_DETOUR_FACTOR of best solo route.
"""

from __future__ import annotations
import math
from typing import List, Tuple

MAX_DETOUR_FACTOR = 1.35   # pooled route may be at most 35% longer than solo
MIN_SCORE_THRESHOLD = 0.40  # normalised efficiency score below which we reject

class Rider:
    def __init__(self, id: str, lat: float, lon: float):
        self.id = id
        self.lat = lat
        self.lon = lon

def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance between two points in kilometres."""
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))

def nearest_neighbour_tour(riders: List[Rider]) -> Tuple[List[str], float]:
    """
    Nearest-neighbour greedy TSP heuristic starting from rider[0].
    Returns (ordered_id_list, total_distance_km).
    """
    unvisited = list(riders)
    tour: List[Rider] = [unvisited.pop(0)]
    total_dist = 0.0

    while unvisited:
        last = tour[-1]
        nearest = min(
            unvisited,
            key=lambda r: haversine_km(last.lat, last.lon, r.lat, r.lon),
        )
        total_dist += haversine_km(last.lat, last.lon, nearest.lat, nearest.lon)
        tour.append(nearest)
        unvisited.remove(nearest)

    return [r.id for r in tour], total_dist

def evaluate(riders: List[Rider]) -> dict:
    if len(riders) == 0:
        return {"isValid": False, "score": 0.0, "sequence": [], "detourOk": False}

    if len(riders) == 1:
        return {"isValid": True, "score": 1.0, "sequence": [riders[0].id], "detourOk": True}

    # Sum of individual (solo) shortest distances from each rider to their "centroid"
    centroid_lat = sum(r.lat for r in riders) / len(riders)
    centroid_lon = sum(r.lon for r in riders) / len(riders)
    solo_total = sum(haversine_km(r.lat, r.lon, centroid_lat, centroid_lon) * 2 for r in riders)

    sequence, pooled_dist = nearest_neighbour_tour(riders)

    if solo_total == 0:
        detour_ratio = 1.0
    else:
        detour_ratio = pooled_dist / solo_total

    detour_ok = detour_ratio <= MAX_DETOUR_FACTOR

    # Score: 1 = perfect overlap, 0 = no savings at all
    score = max(0.0, 1.0 - detour_ratio / MAX_DETOUR_FACTOR)
    is_valid = detour_ok and score >= MIN_SCORE_THRESHOLD

    return {
        "isValid": is_valid,
        "score": round(score, 4),
        "sequence": sequence,
        "detourOk": detour_ok,
        "detourRatio": round(detour_ratio, 4),
    }
