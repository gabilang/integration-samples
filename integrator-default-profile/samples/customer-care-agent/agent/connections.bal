import ballerina/ai;

final ai:Wso2ModelProvider wso2ModelProvider = check ai:getDefaultModelProvider();

final AiMcpbasetoolkit aiMcpbasetoolkit = check new ("http://localhost:8080/mcp");
