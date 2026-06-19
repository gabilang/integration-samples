import ballerina/ftp;
import ballerina/io;
import ballerina/log;

// Listen for files on an SFTP server
listener ftp:Listener WeatherData = new (
    protocol = ftp:SFTP,
    host = sftpHost,
    port = 22,
    path = "/pub/example/",
    auth = {
        credentials: {
            username: sftpUser,
            password: sftpPassword
        },
        preferredMethods: [ftp:PASSWORD]
    },
    pollingInterval = 10, // Check for new files every 10 seconds
    fileNamePattern = "(.*).txt" // Process only .txt files
    // sftpSshKnownHosts omitted => host-key verification is skipped (fine for this public test server)
);

// Triggered when new files are added to the FTP path
service ftp:Service on WeatherData {
    remote function onFileChange(ftp:WatchEvent & readonly event, ftp:Caller caller) returns error? {
        do {
            // Process each newly added file
            foreach ftp:FileInfo addedFile in event.addedFiles {
                // Get file content as a byte stream
                stream<byte[] & readonly, io:Error?> fileStream = check caller->get(addedFile.pathDecoded);
                // Read the first chunk of data
                record {|byte[] value;|}? content = check fileStream.next();

                if content is record {|byte[] value;|} {
                    // Convert byte data to string
                    string fileContent = check string:fromBytes(content.value);

                    // Extract the first line 
                    int? firstLineIndex = fileContent.indexOf("\n");
                    if firstLineIndex is int {
                        string location = fileContent.substring(0, firstLineIndex);
                        log:printInfo("Received file. First line: " + location);
                    }
                } else {
                    log:printError("Failed to read weather content");
                }
            }
        } on fail error err {
            // Log unexpected errors during processing
            log:printError("Error: " + err.message());
        }
    }
}
