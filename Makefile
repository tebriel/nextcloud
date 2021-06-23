build:
	$(MAKE) -C packer build

plan:
	$(MAKE) -C terraform plan

apply:
	$(MAKE) -C terraform apply

