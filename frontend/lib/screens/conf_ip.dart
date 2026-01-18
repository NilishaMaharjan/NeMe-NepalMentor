//import in all files to connect to backend 
const String serverIP = "192.168.1.7";
const int serverPort = 3000;
const String serverProtocol = "http";

String get baseUrl => '$serverProtocol://$serverIP:$serverPort';    