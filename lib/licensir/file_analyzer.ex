defmodule Licensir.FileAnalyzer do
  # The directory to store license files in
  @license_dir "licenses"

  # The file names to check for licenses
  @license_files ["LICENSE", "LICENSE.md", "LICENSE.txt"]

  # The files that contain the actual text for each license
  @files [
    apache2: ["Apache2_text.txt", "Apache2_text.variant-2.txt", "Apache2_url.txt"],
    bsd: ["BSD-3.txt", "BSD-3.variant-2.txt"],
    cc0: ["CC0-1.0.txt"],
    gpl_v2: ["GPLv2.txt"],
    gpl_v3: ["GPLv3.txt"],
    isc: ["ISC.txt", "ISC.variant-2.txt"],
    lgpl: ["LGPL.txt"],
    mit: ["MIT.txt", "MIT.variant-2.txt", "MIT.variant-3.txt"],
    mpl2: ["MPL2.txt"],
    licensir_mock_license: ["LicensirMockLicense.txt"]
  ]

  def analyze(dir_path) do
    Enum.find_value(@license_files, fn file_name ->
      dir_path
      |> Path.join(file_name)
      |> save_file()
      |> File.read()
      |> case do
        {:ok, content} -> analyze_content(content)
        {:error, _} -> nil
      end
    end)
  end

  # Save license files to a local directory
  defp save_file(file_path) when is_bitstring(file_path) do
    sections = String.split(file_path, "/")
    app = Enum.at(sections, length(sections) - 2)

    root_dir =
      sections
      |> Enum.take(length(sections) - 3)
      |> Enum.join("/")

    license_dir = "#{root_dir}/licenses/#{app}"
    license_file = "#{license_dir}/LICENSE.txt"

    if :ok == File.mkdir_p(license_dir) do
      File.cp(file_path, license_file)
    end

    file_path
  end

  defp save_file(path), do: path

  # Returns the first license that matches
  defp analyze_content(content) do
    Enum.find_value(@files, fn {license, license_files} ->
      found =
        Enum.find(license_files, fn license_file ->
          license =
            :licensir
            |> :code.priv_dir()
            |> Path.join("licenses")
            |> Path.join(license_file)
            |> File.read!()

          # Returns true only if the content is a superset of the license text
          clean(content) =~ clean(license)
        end)

      if found, do: license, else: nil
    end) || :unrecognized_license_file
  end

  defp clean(content), do: String.replace(content, ~r/\v/, "")
end
