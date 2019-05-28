{ stdenv, fetchFromGitHub, buildGoModule }:
buildGoModule rec {
  name = "terraform-provider-elasticsearch-${version}";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "phillbaker";
    repo = "terraform-provider-elasticsearch";
    rev = "ad8f939e9ceaec4246ebb756cc26538f8eeab469";
    sha256 = "0w9h3j6vdavq80a10d5b9w3ilfsgaay1zsysf0pdh7n3x4j6ad7v";
  };

  modSha256 = "1xk21xswqwpv34j4ba4fj8lcbvfdd12x7rq1hrdyd21mdhmrhw0p";

  subPackages = [ "." ];

  # Terraform allow checking the provider versions, but this breaks
  # if the versions are not provided via file paths.
  postInstall = "mv $out/bin/terraform-provider-elasticsearch{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for elasticsearch";
    homepage = "https://github.com/phillbaker/terraform-provider-elasticsearch";
    license = licenses.mpl20;
    maintainers = with maintainers; [ basvandijk ];
  };
}
