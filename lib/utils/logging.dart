

class Logger {

  log(message) {
    print("$DateTime.now() [LOG] $message");
  }

  debug(message) {
    log(message);
  }
  
  warn(message) {
    log(message);
  }

  error(message, Exception exception) {
    log(message);
  }

}