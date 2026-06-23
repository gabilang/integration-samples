import ballerinax/kafka;

// Kafka security settings. The defaults keep the local docker-compose broker on
// PLAINTEXT. To connect to a TLS-secured cluster such as Aiven, set these values
// in Config.toml (see README). Leave them at their defaults for local testing.
configurable string kafkaSecurityProtocol = "PLAINTEXT";
configurable string kafkaCaCertPath = "";
configurable string kafkaClientCertPath = "";
configurable string kafkaClientKeyPath = "";
configurable string kafkaSaslMechanism = "PLAIN";
configurable string kafkaSaslUsername = "";
configurable string kafkaSaslPassword = "";

isolated function getKafkaSecurityProtocol() returns kafka:SecurityProtocol {
    match kafkaSecurityProtocol {
        "SSL" => {
            return kafka:PROTOCOL_SSL;
        }
        "SASL_SSL" => {
            return kafka:PROTOCOL_SASL_SSL;
        }
        "SASL_PLAINTEXT" => {
            return kafka:PROTOCOL_SASL_PLAINTEXT;
        }
        _ => {
            return kafka:PROTOCOL_PLAINTEXT;
        }
    }
}

// Builds a SecureSocket from the configured PEM file paths: the CA cert is used to
// trust the broker, and the optional client cert + key enable mutual-TLS (Aiven's
// default "client certificate" authentication). Returns () when no CA cert is set.
isolated function getKafkaSecureSocket() returns kafka:SecureSocket? {
    if kafkaCaCertPath == "" {
        return ();
    }
    if kafkaClientCertPath != "" && kafkaClientKeyPath != "" {
        return {
            cert: kafkaCaCertPath,
            key: {certFile: kafkaClientCertPath, keyFile: kafkaClientKeyPath}
        };
    }
    return {cert: kafkaCaCertPath};
}

// Builds SASL credentials when a username is configured (for SASL/SCRAM clusters).
isolated function getKafkaAuth() returns kafka:AuthenticationConfiguration? {
    if kafkaSaslUsername == "" {
        return ();
    }
    kafka:AuthenticationMechanism saslMechanism = kafka:AUTH_SASL_PLAIN;
    if kafkaSaslMechanism == "SCRAM-SHA-256" {
        saslMechanism = kafka:AUTH_SASL_SCRAM_SHA_256;
    } else if kafkaSaslMechanism == "SCRAM-SHA-512" {
        saslMechanism = kafka:AUTH_SASL_SCRAM_SHA_512;
    }
    return {mechanism: saslMechanism, username: kafkaSaslUsername, password: kafkaSaslPassword};
}
