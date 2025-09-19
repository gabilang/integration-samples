import ballerina/http;

service / on new http:Listener(9090) {

    // This function responds with `string` value `Hello, World!` to HTTP GET requests.
    resource function get greeting() returns string {
        return "Hello, World!";
    }

    resource function get hello(string foo) returns string {
        return "Hello, World!";
    }

    resource function get bar() returns string {
        return "Hello, World!";
    }
}

