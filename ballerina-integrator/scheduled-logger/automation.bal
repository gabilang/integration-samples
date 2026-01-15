import ballerina/io;
import ballerina/time;

configurable string name = ?;
configurable int intervalInSeconds = ?;
configurable int[] logAtSeconds = ?;
configurable map<int> configMap = ?;


public function main() returns error? {
    // Get the current timestamp
    time:Utc currentTime = time:utcNow();
    string formattedTime = time:utcToString(currentTime);

    io:println("Configured Name: " + name);
    io:println("Logging Interval (seconds): " + intervalInSeconds.toString());
    io:println("Log at Seconds: " + logAtSeconds.toString());
    io:println("Config Map: " + configMap.toString());

    // Print the timestamp in UTC format
    io:println("Current timestamp: " + formattedTime);

    if intervalInSeconds < 1 {
        panic error("Interval must be at least 1 second");
    }
}
