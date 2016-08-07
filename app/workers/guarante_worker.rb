class GuaranteWorker
  include Sneakers::Worker

  from_queue 'guarante_task', env: nil

  def work(raw_post)
    # GuaranteProcess.push raw_post
    Guarante.build raw_post
    
    ack!
  end
end
