module NetworkMiddleware

  def initialize
    settings = Settings.__send__ @root
    settings.each do |k, v|
      instance_variable_set "@#{k}", v
    end
    @connect = Faraday.new(:url => @remote) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end
  end

  def get_data(params={}, head_params={})
    method = params[:method] || params['method']
    result = send("use_#{method}", params, head_params)
  end

  private
  def use_post(params={}, head_params={})
    request_params = params[:data] || params['data']

    response = @connect.post do |request|
      request.url @api_path
      # request.headers['Content-Type'] = 'text/plain'
      # request.headers['Accept'] = 'application/json'
      request.body = request_params
    end
    MultiJson.load(response.body)
  end

  def use_get(params={}, head_params={})
    response = @connect.get do |request|
      request.url @api_path
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
      request_params = params[:data] || params['data']
      if request_params.present?  
        request.body = request_params.to_json
      end
    end
    MultiJson.load(response.body)
  end

end
