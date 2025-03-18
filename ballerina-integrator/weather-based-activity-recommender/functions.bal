import ballerina/http;
import ballerina/io;
import ballerinax/openai.chat;

function generateWeatherSummary(json weatherData) returns string {

    // Extract relevant weather information
    map<json> weather = <map<json>>weatherData;
    map<json> main = <map<json>>weather.get("main");
    map<json>[] weatherDetails = <map<json>[]>weather.get("weather");

    float temperature = <float>main.get("temp") - 273.15; // Convert from Kelvin to Celsius
    string weatherCondition = <string>weatherDetails[0].get("main");
    string weatherDescription = <string>weatherDetails[0].get("description");

    // Prepare the weather summary
    string weatherSummary = string `Current weather in ${cityName}: ${weatherCondition} (${weatherDescription}) with temperature of ${temperature.toFixedString(1)}°C`;
    return weatherSummary;
}

function getWeatherData() returns json|error {
    string endpoint = string `/data/2.5/weather?q=${cityName}&appid=${weatherApiKey}`;
    http:Response response = check weatherClient->get(endpoint);

    if response.statusCode == 200 {
        return response.getJsonPayload();
    } else {
        return error("Failed to fetch weather data: " + response.statusCode.toString());
    }
}

function generateAIRecommendations(string weatherSummary) returns string|error {
    string interestsStr = string:'join(", ", ...userInterests);

    string prompt = string `
Based on the following weather information and user interests, suggest 3-5 appropriate activities for today. Be specific and explain why each activity is suitable for the weather.

Weather: ${weatherSummary}
User interests: ${interestsStr}
User name: ${userName}

Format the response as a numbered list with brief explanations.
`;

    chat:CreateChatCompletionRequest request = {
        model: "gpt-3.5-turbo",
        messages: [
            {
                role: "system",
                content: "You are a helpful assistant that recommends personalized activities based on weather conditions."
            },
            {
                role: "user",
                content: prompt
            }
        ],
        temperature: 0.7,
        max_tokens: 500
    };

    chat:CreateChatCompletionResponse response = check openaiClient->/chat/completions.post(request);
    return response.choices[0].message.content ?: "No recommendations found.";
}

function showActivityInfo(string weatherSummary, string? recommendations) {
    // Print the recommendations
    io:println("\n===== WEATHER-BASED ACTIVITY RECOMMENDATIONS =====");
    io:println("For: " + userName);
    io:println("\n" + weatherSummary);
    io:println("\nRECOMMENDED ACTIVITIES:");
    io:println(recommendations);
    io:println("===============================================\n");
}
