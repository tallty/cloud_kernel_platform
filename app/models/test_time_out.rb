class TestTimeOut

  def process
    count = 1
    while 1
      p "------------------------test--------------------------"
      p count
      count = count + 1
      sleep 10
    end
  end
end
