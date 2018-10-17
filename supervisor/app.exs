# Start supervisor
IO.inspect App.Supervisor.start_link

# Get Service Pid
IO.inspect App.Service.pid

# Kill Service
IO.inspect App.Service.kill

# Get Service Pid to ensure it was restarted
IO.inspect App.Service.pid
