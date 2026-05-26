FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="rnaseq-locus-varcall"
LABEL org.opencontainers.image.description="Reproducible RNA-seq variant calling at a user-defined locus (samtools + bcftools)"
LABEL org.opencontainers.image.source="https://github.com/Christofferfrisk/rnaseq-locus-varcall"
LABEL org.opencontainers.image.licenses="MIT"

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        procps \
        tini \
    && rm -rf /var/lib/apt/lists/*

USER $MAMBA_USER

RUN micromamba install -y -n base -c conda-forge -c bioconda \
        samtools=1.20 \
        bcftools=1.20 \
        htslib=1.20 \
    && micromamba clean --all --yes

ENV PATH=/opt/conda/bin:$PATH

WORKDIR /work

COPY --chown=$MAMBA_USER:$MAMBA_USER call_variants.sh /usr/local/bin/call_variants
RUN chmod +x /usr/local/bin/call_variants

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/call_variants"]
CMD ["--help"]
