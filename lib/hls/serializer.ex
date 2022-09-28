defmodule HLS.Serializer do
  def run(manifest) do
    HLS.Serializers.M3U8.render(manifest: manifest)
  end
end
