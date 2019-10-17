{ stdenv, fetchFromGitHub, buildGoModule }:
buildGoModule rec {
  pname = "terraform-provider-proxmox";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "Telmate";
    repo = "terraform-provider-proxmox";
    rev = "7a4a86f9e1fa6b65bfc963b12bf375333d766ea7";
    sha256 = "0kpyn1859y16sfb0baazks5dr13gg9yg4ymm79y6r6pw78flxgy5";
  };

  modSha256 = "0957h450f05f0djjd5nadfygi5is7l2py9mv655yynvq7vm0391f";

  subPackages = [
    "cmd/terraform-provider-proxmox"
    "cmd/terraform-provisioner-proxmox"
  ];

  meta = with stdenv.lib; {
    description = "Terraform provider for Proxmox";
    homepage = "https://github.com/Telmate/terraform-provider-proxmox";
    license = licenses.mit;
    maintainers = with maintainers; [ basvandijk ];
  };
}
