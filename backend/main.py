import asyncio
import os

import httpx
from dotenv import load_dotenv

load_dotenv()
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

OPEN_FOOD_FACTS_URL = "https://world.openfoodfacts.org/api/v2/product/{barcode}.json"
OPEN_PRODUCTS_FACTS_URL = "https://world.openproductsfacts.org/api/v2/product/{barcode}.json"



class ScanRequest(BaseModel):
    barcode: str


class AnalyzeRequest(BaseModel):
    product_name: str | None = None
    brand: str | None = None
    ingredients: list[str] = []
    packaging: dict = {}


async def _fetch_product(client: httpx.AsyncClient, url: str) -> dict | None:
    for attempt in range(3):
        response = await client.get(url, headers={"User-Agent": "FullyHacks2026/1.0"})
        if response.status_code == 429:
            await asyncio.sleep(1.5 * (attempt + 1))
            continue
        if response.status_code != 200:
            return None
        data = response.json()
        return data.get("product") if data.get("status") == 1 else None
    raise HTTPException(status_code=429, detail=f"Open Food Facts returned 429 for {url.split('/')[-1].split('.')[0]}")


@app.post("/scan")
async def scan_barcode(request: ScanRequest):
    async with httpx.AsyncClient(timeout=10.0) as client:
        product = await _fetch_product(
            client, OPEN_FOOD_FACTS_URL.format(barcode=request.barcode)
        )
        if product is None:
            product = await _fetch_product(
                client, OPEN_PRODUCTS_FACTS_URL.format(barcode=request.barcode)
            )

    if product is None:
        raise HTTPException(status_code=404, detail=f"Product not found for barcode: {request.barcode}")

    ingredients_raw = product.get("ingredients_text") or product.get("ingredients_text_en") or ""
    ingredients = [i.strip() for i in ingredients_raw.split(",") if i.strip()] if ingredients_raw else []

    packaging = {
        "packaging_text": product.get("packaging_text"),
        "packaging_tags": product.get("packaging_tags", []),
        "ecoscore_grade": product.get("ecoscore_grade"),
        "ecoscore_score": product.get("ecoscore_score"),
        "nutriscore_grade": product.get("nutriscore_grade"),
        "labels_tags": product.get("labels_tags", []),
        "countries_tags": product.get("countries_tags", []),
    }
    packaging = {k: v for k, v in packaging.items() if v is not None}

    return {
        "barcode": request.barcode,
        "product_name": product.get("product_name") or product.get("product_name_en"),
        "brand": product.get("brands"),
        "ingredients": ingredients,
        "packaging": packaging,
    }


_GRADE_SCORE = {"a": 10, "b": 8, "c": 6, "d": 4, "e": 2}

# Ingredients that hurt sustainability
_ECO_BAD_INGREDIENTS = {
    "palm oil":     ("🌴 Palm oil — linked to deforestation (-2 pts)", -2),
    "soy lecithin": ("🌱 Soy lecithin — often from deforested land (-1 pt)", -1),
    "beef":         ("🐄 Beef — very high carbon footprint (-2 pts)", -2),
    "pork":         ("🐷 Pork — high carbon footprint (-1 pt)", -1),
}
_BAD_PACKAGING = {
    "en:plastic":                              ("🧴 Plastic packaging — hard to recycle (-2 pts)", -2),
    "en:non-recyclable":                       ("🚫 Non-recyclable packaging (-2 pts)", -2),
    "en:pet-1-polyethylene-terephthalate":     ("♳ PET plastic packaging (-1 pt)", -1),
}
_GOOD_PACKAGING = {
    "en:cardboard":   ("📦 Cardboard packaging — recyclable (+1 pt)", +1),
    "en:glass":       ("🫙 Glass packaging — recyclable (+1 pt)", +1),
    "en:recycled":    ("♻️ Made from recycled materials (+2 pts)", +2),
    "en:compostable": ("🌿 Compostable packaging (+2 pts)", +2),
}
_GOOD_LABELS = {"en:organic", "en:fair-trade", "en:vegan", "en:vegetarian", "en:no-additives", "en:gluten-free"}
_GOOD_LABEL_BONUS = {"en:organic": +2, "en:fair-trade": +2, "en:vegan": +1, "en:vegetarian": +1}
_GOOD_LABEL_MSG = {
    "en:organic":     "🌾 Certified organic (+2 pts)",
    "en:fair-trade":  "🤝 Fair-trade certified (+2 pts)",
    "en:vegan":       "🌱 Vegan — lower environmental impact (+1 pt)",
    "en:vegetarian":  "🥦 Vegetarian — lower environmental impact (+1 pt)",
}

_NUTRI_EXPLAIN = {
    "a": "Nutri-Score A — excellent nutritional quality",
    "b": "Nutri-Score B — good nutritional quality",
    "c": "Nutri-Score C — moderate nutritional quality",
    "d": "Nutri-Score D — poor nutritional quality",
    "e": "Nutri-Score E — very poor nutritional quality",
}

_HEALTH_BAD_INGREDIENTS = {
    "high fructose corn syrup": "high fructose corn syrup (raises blood sugar)",
    "hydrogenated":             "hydrogenated oils (trans fats)",
    "sodium nitrate":           "sodium nitrate (processed meat preservative)",
    "artificial color":         "artificial colors",
    "artificial flavor":        "artificial flavors",
}

_ALTERNATIVES = {
    "good": [
        {"name": "Local Organic Option",    "brand": "Your local store", "score": 85, "reason": "Shorter supply chain, organic farming"},
        {"name": "Bulk / unpackaged version","brand": "Bulk food store",  "score": 80, "reason": "No packaging waste"},
    ],
    "mid": [
        {"name": "Organic alternative",         "brand": "Look for organic brands",  "score": 75, "reason": "Organic farming reduces pesticide use"},
        {"name": "Fair-trade certified version", "brand": "Fair-trade brands",        "score": 72, "reason": "Supports ethical supply chains"},
    ],
    "bad": [
        {"name": "Organic & fair-trade swap",   "brand": "Look for certified brands", "score": 78, "reason": "Avoid palm oil & high-impact ingredients"},
        {"name": "Locally sourced alternative", "brand": "Local producers",           "score": 74, "reason": "Lower transport emissions"},
        {"name": "Whole food version",          "brand": "Make it at home",           "score": 90, "reason": "No additives, full control"},
    ],
}


@app.post("/analyze")
async def analyze_product(request: AnalyzeRequest):
    pkg = request.packaging
    ingredients_lower = " ".join(request.ingredients).lower()
    packaging_tags = pkg.get("packaging_tags") or []
    labels = pkg.get("labels_tags") or []

    # ── Sustainability score (ingredient + packaging + label signals) ──
    score = 6  # start neutral-good

    eco_flags = []
    eco_positives = []

    for key, (msg, delta) in _ECO_BAD_INGREDIENTS.items():
        if key in ingredients_lower:
            score += delta
            eco_flags.append(msg)

    for tag, (msg, delta) in _BAD_PACKAGING.items():
        if tag in packaging_tags:
            score += delta
            eco_flags.append(msg)

    for tag, (msg, delta) in _GOOD_PACKAGING.items():
        if tag in packaging_tags:
            score += delta
            eco_positives.append(msg)

    for label in labels:
        if label in _GOOD_LABEL_BONUS:
            score += _GOOD_LABEL_BONUS[label]
            eco_positives.append(_GOOD_LABEL_MSG.get(label, label.replace("en:", "").replace("-", " ").title()))

    sustainability_score = max(1, min(10, score))

    if not eco_flags:
        eco_flags = ["No major sustainability concerns detected"]
    if not eco_positives:
        eco_positives = ["No eco certifications or recyclable packaging found"]

    # ── Health score (nutriscore) ──
    nutri_grade = str(pkg.get("nutriscore_grade") or "").lower()
    health_score = _GRADE_SCORE.get(nutri_grade, 5)

    health_flags = [msg for key, msg in _HEALTH_BAD_INGREDIENTS.items() if key in ingredients_lower]
    if nutri_grade in ("d", "e"):
        health_flags.append(_NUTRI_EXPLAIN[nutri_grade])
    if not health_flags:
        health_flags = ["No major health concerns detected"]

    if nutri_grade in ("a", "b"):
        eco_positives.append(_NUTRI_EXPLAIN[nutri_grade])

    alternatives = _ALTERNATIVES["good" if sustainability_score >= 7 else "mid" if sustainability_score >= 5 else "bad"]

    summary = (
        f"{request.product_name or 'This product'} scored {sustainability_score}/10 for sustainability "
        f"and {health_score}/10 for health."
    )

    return {
        "summary": summary,
        "health_score": health_score,
        "sustainability_score": sustainability_score,
        "eco_flags": eco_flags,
        "health_flags": health_flags,
        "eco_positives": eco_positives,
        "alternatives": alternatives,
    }
