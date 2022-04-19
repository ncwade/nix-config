{ pkgs, ... }:
let
  stevenBlackList = pkgs.stdenv.mkDerivation {
    name = "steven-black-adblock";

    src = (pkgs.fetchFromGitHub {
      owner = "StevenBlack";
      repo = "hosts";
      rev = "3.9.62";
      sha256 = "1xgxia1vrkrax80ab24a90ync5zps0y7zwj2v1689kzx43dakfn0";
    } + "/hosts");

    phases = [ "installPhase" ];

    installPhase = ''
      ${pkgs.gawk}/bin/awk '{sub(/\r$/,"")} {sub(/^127\.0\.0\.1/,"0.0.0.0")} BEGIN { OFS = "" } NF == 2 && $1 == "0.0.0.0" { print "local-zone: \"", $2, "\" static"}' $src | tr '[:upper:]' '[:lower:]' | sort -u >  $out
    '';
  };
in {
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
  services.unbound = {
    enable = true;
    settings = {
      server = {
        include = [
          "${stevenBlackList}"
        ];
        access-control = [
          "127.0.0.0/24 allow"
          "192.168.1.0/24 allow"
          "192.168.2.0/24 allow"
          "192.168.3.0/24 allow"
        ];
        interface = [
          "0.0.0.0"
        ];
        local-zone = [
          "home.ncw. transparent"
        ];
        local-data = [
          ''"nas1.home.ncw A 192.168.3.9"''
          ''"rock1.home.ncw A 192.168.3.12"''
          ''"rock2.home.ncw A 192.168.3.13"''
        ];
      };
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = "yes";
          forward-addr = [
          "1.1.1.1@853#cloudflare-dns.com"
          "1.0.0.1@853#cloudflare-dns.com"
        ];
      }
    ];
  };
};
}
