Sneakers.configure({
  :amqp => 'amqp://guest:123456@10.228.96.102:5672',
  :workers => 2,
  :threads => 20,
  :share_threads => true,
  :log => 'log/sneakers.log',
  :daemonize => true,
  :env => 'production'
})
Sneakers.logger.level = Logger::INFO
