import ballerina/http;

configurable string str = ?; 
configurable int a = ?;
configurable int b = ?;
configurable int c = ?;
configurable string foo = ?;
configurable string baz = ?;

service / on new http:Listener(9090) {

    // This function responds with `string` value `Hello, World!` to HTTP GET requests.
    resource function get greeting() returns string {
        return "Hello, World!";
    }

    resource function get hello(string foo) returns string {
        return str;
    }

    resource function get bar() returns string {
        return foo;
    }

    resource function get foo() returns string {
        return baz;
    }

    resource function get getA() returns int {
        return a;
    }

    resource function get getB() returns int {
        return b;
    }
}

