# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
# load sneakers tasks
require 'sneakers/tasks'

Rails.application.load_tasks

namespace :rabbitmq do
  desc 'Setup routing'
  task :setup do
    require 'bunny'
    conn = Bunny.new("amqp://guest:123456@10.228.96.102:5672", :automatically_recover => false)
    conn.start

    # publish/subscribe
    ch = conn.create_channel
    x = ch.fanout('message.guarantees')
    ch.queue('guarante_task', durable: true).bind(x).subscribe

    # x = ch.fanout('message.interface')
    # ch.queue('analyze_interface', durable: true).bind(x).subscribe

    # x = ch.fanout("message.machine_health")
    # ch.queue("machine_health", durable: true).bind(x).subscribe

    # ch_task = conn.create_channel
    # ch_task.fanout('message.task')
    # get or create queue (note the durable setting)
    # queue_task = ch_task.queue('worker.task', durable: true)
    # queue_task.bind('message.task')
    
    # ch_interface = conn.create_channel
    # ch_interface.fanout('message.interface')
    # queue_interface = ch_interface.queue('worker.interface', durable: true)
    # queue_interface.bind('message.interface')
    conn.close
  end
end
