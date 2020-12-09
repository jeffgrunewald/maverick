defmodule Maverick.TestApi do
  use Maverick.Api, otp_app: :maverick
end

defmodule Maverick.Plug.TestApi do
  use Maverick.Api, otp_app: :maverick, server: Maverick.Server.Plug
end
