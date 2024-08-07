# Delete all the assets for a given tenant identified by "schema_name" below (line 62)

def delete_all_assets():
    from source.models import Vulnerability, Control, Scan

    # for obj in Scan.objects.exclude(
    #     data_type__iexact="Trivy",
    # ).iterator(
    #     chunk_size=100,
    # ):
    obj = Scan.objects.exclude(data_type__iexact="Trivy")
    print(f"about to delete Scan : {obj.count()}")
    obj.delete()

    for obj in (
        Asset.objects.filter(level=1)
        .exclude(
            original_source__iexact="Trivy",
        )
        .iterator(chunk_size=100)
    ):
        with Asset.objects.disable_mptt_updates():
            print(f"about to delete Asset(level 1): {obj.id}")
            obj.delete()

    for obj in (
        Asset.objects.filter(level=0)
        .exclude(
            original_source__iexact="Trivy",
        )
        .iterator(chunk_size=100)
    ):
        with Asset.objects.disable_mptt_updates():
            print(f"about to delete Asset level 0: {obj.id}")
            obj.delete()

    # for obj in Vulnerability.objects.exclude(
    #     data_type__iexact="Trivy",
    # ).iterator(
    #     chunk_size=100,
    # ):
    obj = Vulnerability.objects.exclude(data_type__iexact="Trivy")
    print(f"going to delete Vulnerabilities, count = {obj.count()}")
    obj.delete()

    # for obj in Control.objects.all().iterator(
    #     chunk_size=100,
    # ):
    obj = Control.objects.all()
    print(f"going to delete Controls, count = {obj.count()}")
    obj.delete()

from django_tenants.utils import schema_context, get_public_schema_name
from source.tasks import sync_update_role_permissions
from tenant.models import Client
from source.models import Asset
from tenant.models import AssetType
from django.db import transaction
import time
from source.models import asset
for schema_name in Client.objects.exclude(schema_name=get_public_schema_name()).values_list(
"schema_name",
flat=True,
):
    with schema_context(schema_name):
        print(f"deleting assets from schema: {schema_name}")
        delete_all_assets()
