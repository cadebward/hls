defmodule HLS.Media do
  defstruct [
    :name,
    :type,
    :uri,
    :group_id,
    :language,
    :default,
    :autoselect,
    :forced
  ]

  def build(%HLS.M3ULine{} = line) do
    %__MODULE__{
      name: HLS.M3ULine.get_attribute(line, "name"),
      type: HLS.M3ULine.get_attribute(line, "type"),
      uri: HLS.M3ULine.get_attribute(line, "uri"),
      group_id: HLS.M3ULine.get_attribute(line, "group-id"),
      language: HLS.M3ULine.get_attribute(line, "language"),
      default: HLS.M3ULine.get_boolean_attribute(line, "default"),
      autoselect: HLS.M3ULine.get_boolean_attribute(line, "autoselect"),
      forced: HLS.M3ULine.get_boolean_attribute(line, "forced")
    }
  end
end
