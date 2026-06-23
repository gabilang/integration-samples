import ballerinax/kafka;

final kafka:Producer orderProducer = check initOrderProducer();

isolated function initOrderProducer() returns kafka:Producer|error {
    kafka:ProducerConfiguration producerConfig = {securityProtocol: getKafkaSecurityProtocol()};
    kafka:SecureSocket? secureSocket = getKafkaSecureSocket();
    if secureSocket is kafka:SecureSocket {
        producerConfig.secureSocket = secureSocket;
    }
    kafka:AuthenticationConfiguration? auth = getKafkaAuth();
    if auth is kafka:AuthenticationConfiguration {
        producerConfig.auth = auth;
    }
    return new (kafkaBootstrapServers, producerConfig);
}
