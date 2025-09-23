import ballerina/http;

configurable string str = ?; 
configurable int a = ?;
configurable int b = ?;
configurable int c = ?;
configurable int d = ?;
configurable int e = ?;
configurable string foo = ?;
configurable string baz = ?;

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

    resource function get foo() returns string {
        return str;
    }
}

