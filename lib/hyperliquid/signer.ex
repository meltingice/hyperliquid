defmodule Hyperliquid.Signer do
  # Only compile NIF if Rustler is available and native code exists
  # This allows the package to work without Rust compiler installed
  if Code.ensure_loaded?(Rustler) and File.dir?("native/signer") do
    use Rustler,
      otp_app: :hyperliquid,
      crate: "signer_nif",
      path: "native/signer",
      skip_compilation?: System.get_env("SKIP_RUSTLER_COMPILE") == "true"
  end

  @nif_error_msg "Rust NIF not available. Ensure native/signer directory exists and run: mix deps.compile rustler --force"

  # Fallbacks when NIF is not loaded - return descriptive error tuples
  def compute_connection_id(_action_json, _nonce, _vault_address) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def compute_connection_id_ex(_action_json, _nonce, _vault_address, _expires_after) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_exchange_action(_pk, _action_json, _nonce, _is_mainnet, _vault_addr) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_exchange_action_ex(
        _pk,
        _action_json,
        _nonce,
        _is_mainnet,
        _vault_addr,
        _expires_after
      ) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_l1_action(_pk, _connection_id, _is_mainnet) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_usd_send(_pk, _dest, _amount, _time, _is_mainnet) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_withdraw3(_pk, _dest, _amount, _time, _is_mainnet) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_spot_send(_pk, _dest, _token, _amount, _time, _is_mainnet) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_approve_builder_fee(_pk, _builder, _max_fee_rate, _nonce, _is_mainnet) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_approve_agent(_pk, _agent_addr, _agent_name, _nonce, _is_mainnet) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_multi_sig_action_ex(
        _pk,
        _action_json,
        _nonce,
        _is_mainnet,
        _vault_addr,
        _expires_after
      ) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def sign_typed_data(_pk, _domain_json, _types_json, _message_json, _primary_type) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end

  def to_checksum_address(_addr) do
    {:error, {:nif_not_loaded, @nif_error_msg}}
  end
end
