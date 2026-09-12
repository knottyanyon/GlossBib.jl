using DocumenterGlossip
using Test

@testset "DocumenterGlossip" begin
    @test DocumenterGlossip.glossary_link_preprocessor("An {glossary:MPS} is compressed.") ==
        "An [`MPS`](/references/glossary/#mps) is compressed."

    @test DocumenterGlossip.glossary_link_preprocessor(
        "See {glossary:Bond Dimension}."; glossary_path="/refs/"
    ) == "See [`Bond Dimension`](/refs/#bond-dimension)."

    @test occursin("MPS", DocumenterGlossip.glossary_term("MPS"; brief="Matrix Product State"))
    @test occursin("mps", DocumenterGlossip.glossary_html("MPS"))
end
