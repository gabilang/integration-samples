import ballerina/http;
import ballerina/io;

type NewGreeting record {
    string newfrom;
    string newto;
    string newmessage?;
};

type Greeting record {
    string 'from;
    string to;
    string message;
    NewGreeting[] newGreeting;
    map<NewGreeting> greetingStrMap;
};

configurable Greeting nestedGreeting = ?;
// configurable Greeting|NewGreeting greetingN = ?;

configurable string? nullString = "abc";

configurable string|int|null intStringNil = "abc";

configurable string str = ?; 
configurable int a = ?;
configurable int b = ?;
configurable string foo = ?;
configurable string baz = ?;

service / on new http:Listener(9090) {

    resource function get .(string name) returns string {
        // io:println(greetingStrMap);
        io:println(nestedGreeting);
        // Greeting greetingMessage = {"from" : "name2", "to" : "name2", "message" : "BLUE"};

        io:println("intStringNil: ", intStringNil);
        return "greetingMessage";
    }

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

