# Avatar Library Guide

## How to Add Avatars

1. **Add your avatar images** to this folder (`assets/avatars/`)
   - Supported formats: PNG, JPG
   - Recommended size: 200x280 pixels (portrait)
   - Name them descriptively: `finance_male_1.png`, `construction_female_2.png`, etc.

2. **Add avatar metadata** to `avatar_library.json`

## JSON Format

Each avatar entry should look like this:

```json
{
  "id": "unique_id",
  "assetPath": "assets/avatars/your_image.png",
  "description": "Brief description of the avatar",
  "jobKeywords": ["finance", "accountant", "banker"],
  "gender": "male",  // or "female", "neutral", or null for any
  "ageRange": "adult",  // or "young", "senior", or null for any
  "ethnicity": ["white", "asian"],  // or null for any
  "outfit": "formal",  // or "casual", "business", "uniform", etc.
  "accessory": "glasses"  // or "hard hat", "clipboard", null, etc.
}
```

## Matching Algorithm

The app scores each avatar based on:
- **Job title match** (10 points) - highest priority
- **Company/industry match** (5 points)
- **Outfit match** (5 points) - if contact has outfit preference
- **Accessory match** (3 points) - if contact has accessory preference

The avatar with the highest score (minimum 5) is automatically assigned.

## Example Entries

```json
[
  {
    "id": "finance_male_1",
    "assetPath": "assets/avatars/finance_male_1.png",
    "description": "Male finance professional in suit",
    "jobKeywords": ["finance", "accountant", "banker", "financial", "analyst"],
    "gender": "male",
    "ageRange": "adult",
    "ethnicity": null,
    "outfit": "formal",
    "accessory": null
  },
  {
    "id": "construction_female_1",
    "assetPath": "assets/avatars/construction_female_1.png",
    "description": "Female construction worker with hard hat",
    "jobKeywords": ["construction", "contractor", "builder"],
    "gender": "female",
    "ageRange": "adult",
    "ethnicity": null,
    "outfit": "uniform",
    "accessory": "hard hat"
  }
]
```

## Tips

- Add multiple avatars for the same role with different demographics for better matching
- Use broad job keywords to catch variations (e.g., "finance" catches "financial analyst", "financier", etc.)
- Leave optional fields as `null` to make avatars match more contacts
- Test by viewing contacts with different job titles to see which avatars are assigned
