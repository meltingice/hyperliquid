if Code.ensure_loaded?(Ecto.Adapters.Postgres) do
  defmodule Hyperliquid.Repo do
    use Ecto.Repo,
      otp_app: :hyperliquid,
      adapter: Ecto.Adapters.Postgres

    @doc """
    Dynamically configure the database name based on the chain (mainnet/testnet).

    This callback is invoked when the Repo starts up and allows us to modify
    the configuration at runtime. When running on testnet, we append "_testnet"
    to the database name to keep testnet and mainnet data completely separated
    without requiring schema changes.

    ## Examples

    Mainnet configuration (chain: :mainnet):
    - Database URL: ecto://user:pass@host/hyperliquid_dev
    - Actual database: hyperliquid_dev

    Testnet configuration (chain: :testnet):
    - Database URL: ecto://user:pass@host/hyperliquid_dev
    - Actual database: hyperliquid_dev_testnet
    """
    def init(_type, config) do
      config = apply_testnet_database_suffix(config)
      {:ok, config}
    end

    defp apply_testnet_database_suffix(config) do
      # Check if we're running on testnet
      if testnet?() do
        # Get the current database name from config
        config
        |> update_database_name_with_suffix("_testnet")
        |> update_database_url_with_suffix("_testnet")
      else
        config
      end
    end

    defp testnet? do
      # The chain config might not be available during early startup,
      # so we check the application env directly
      case Application.get_env(:hyperliquid, :chain) do
        :testnet -> true
        _ -> false
      end
    end

    defp update_database_name_with_suffix(config, suffix) do
      case Keyword.get(config, :database) do
        nil ->
          config

        db_name ->
          # Only add suffix if not already present
          new_db_name =
            if String.ends_with?(db_name, suffix) do
              db_name
            else
              db_name <> suffix
            end

          Keyword.put(config, :database, new_db_name)
      end
    end

    defp update_database_url_with_suffix(config, suffix) do
      case Keyword.get(config, :url) do
        nil ->
          config

        url ->
          # Parse and modify the database URL
          uri = URI.parse(url)

          new_path =
            case uri.path do
              "/" <> db_name ->
                # Only add suffix if not already present
                new_db_name =
                  if String.ends_with?(db_name, suffix) do
                    db_name
                  else
                    db_name <> suffix
                  end

                "/" <> new_db_name

              path ->
                path
            end

          new_url = URI.to_string(%{uri | path: new_path})
          Keyword.put(config, :url, new_url)
      end
    end
  end
end
