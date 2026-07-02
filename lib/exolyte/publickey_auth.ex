defmodule Exolyte.PublickeyAuth do
  @admin_authsession_db "priv/auth_session"

  def add_key(key, name) do
    db = Exolyte.DB.get_db()
    
    CubDB.put(db, {:adminkey, key}, name)
  end

  def revoke_key(key) do
    db = Exolyte.DB.get_db()

    CubDB.delete(db, {:adminkey, key})
  end

  def verify(public_key_spki_base64, signature_base64, challenge_id) do
    pub_key_der = Base.decode64!(public_key_spki_base64)
    signature = Base.decode64!(signature_base64)

    case get_challenge(challenge_id) do
      {:ok, message} -> 
        {:SubjectPublicKeyInfo, _algo, key_bitstring} = :public_key.der_decode(:SubjectPublicKeyInfo, pub_key_der)
        is_valid = :crypto.verify(:eddsa, :none, message, signature, [key_bitstring, :ed25519])
    
        is_valid

      _ ->
        false
    end
  end

  def create_challenge do
    cuuid = UUID.uuid4()
    cvalue = UUID.uuid4()
    path = Path.join([@admin_authsession_db, "#{cuuid}.json"])
    expire = System.os_time(:second) + 60 * 60 * 24
    
    data = %{
      value: cvalue,
      expire_at: expire
    }

    File.write!(path, JSON.encode!(data))

    {:ok, cuuid, cvalue}
  end

  def get_challenge(challenge_id) do
    path = Path.join([@admin_authsession_db, "#{challenge_id}.json"])

    if File.exists?(path) do
      {:ok, raw} = File.read(path)
      data = Jason.decode!(raw)

      if data["expire_at"] < System.os_time(:second) do
        {:error, :expired}
      else
        {:ok, data["value"]}
      end
    else
      {:error, :not_found}
    end
  end
end