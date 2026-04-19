import os

import httpx
from dotenv import load_dotenv

load_dotenv()
from fastapi import FastAPI, HTTPException
from google import genai
from pydantic import BaseModel

app = FastAPI()

OPEN_FOOD_FACTS_URL = "https://world.openfoodfacts.org/api/v2/product/{barcode}.json"

gemini_client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])


class ScanRequest(BaseModel):
    barcode: str


class AnalyzeRequest(BaseModel):
    product_name: str | None = None
    brand: str | None = None
    ingredients: list[str] = []
    packaging: dict = {}


@app.post("/scan")
async def scan_barcode(request: ScanRequest):
    url = OPEN_FOOD_FACTS_URL.format(barcode=request.barcode)

    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(url, headers={"User-Agent": "FullyHacks2026/1.0"})

    if response.status_code != 200:
        raise HTTPException(status_code=502, detail="Failed to reach Open Food Facts API")

    data = response.json()

    if data.get("status") != 1:
        raise HTTPException(status_code=404, detail=f"Product not found for barcode: {request.barcode}")

    product = data["product"]

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


@app.post("/analyze")
async def analyze_product(request: AnalyzeRequest):
    prompt = f"""You are a sustainability and health analyst. Analyze this food product and return a JSON object with exactly these fields:

- summary: 2-3 sentence plain-English overview
- health_score: integer 1-10 (10 = very healthy)
- sustainability_score: integer 1-10 (10 = very sustainable)
- flags: list of short concern strings (e.g. "high sugar", "non-recyclable packaging")
- positives: list of short positive strings (e.g. "vegan", "low sodium")

Product:
  Name: {request.product_name or "Unknown"}
  Brand: {request.brand or "Unknown"}
  Ingredients: {", ".join(request.ingredients) if request.ingredients else "Not available"}
  Packaging/Environmental data: {request.packaging}

Respond with only valid JSON, no markdown fences."""

    response = gemini_client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
    )

    import json
    try:
        result = json.loads(response.text)
    except json.JSONDecodeError:
        raise HTTPException(status_code=502, detail="Gemini returned malformed JSON")

    return result
