//
//  Fixtures.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

/// Trimmed real payloads captured from the providers.
enum Fixtures {
    static let currentWeather = """
    {
      "coord": { "lon": 2.4064, "lat": 48.8937 },
      "weather": [{ "id": 800, "main": "Clear", "description": "clear sky", "icon": "01d" }],
      "base": "stations",
      "main": {
        "temp": 18.5, "feels_like": 18.0, "temp_min": 16.5, "temp_max": 20.0,
        "pressure": 1013, "humidity": 60
      },
      "visibility": 10000,
      "wind": { "speed": 3.1, "deg": 180 },
      "clouds": { "all": 0 },
      "dt": 1650280800,
      "sys": { "country": "FR", "sunrise": 1650264000, "sunset": 1650314400 },
      "timezone": 7200,
      "id": 2988507,
      "name": "Pantin",
      "cod": 200
    }
    """

    static let currentWeatherWithoutMain = """
    { "coord": { "lon": 2.4, "lat": 48.9 }, "name": "Nowhere", "dt": 1650280800 }
    """

    static let unsplashPhotos = """
    [
      {
        "id": "abc",
        "description": null,
        "alt_description": "Eiffel tower at dusk",
        "urls": { "regular": "https://images.unsplash.com/photo-abc" },
        "user": { "name": "Jane Doe" }
      },
      {
        "id": "def",
        "description": "Seine",
        "alt_description": null,
        "urls": { "regular": "https://images.unsplash.com/photo-def" },
        "user": { "name": null }
      }
    ]
    """
}
