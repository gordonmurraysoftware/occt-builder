// Box -> STEP -> XCAF -> mesh -> meshopt -> WebP. The image build also runs gltfpack -v.
#include <webp/encode.h>

#include <BRepMesh_IncrementalMesh.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRep_Tool.hxx>
#include <IFSelect_ReturnStatus.hxx>
#include <Poly_Triangulation.hxx>
#include <STEPCAFControl_Reader.hxx>
#include <STEPControl_Writer.hxx>
#include <TDocStd_Document.hxx>
#include <TopExp_Explorer.hxx>
#include <TopLoc_Location.hxx>
#include <TopoDS.hxx>
#include <XCAFApp_Application.hxx>
#include <gp_Pnt.hxx>
#include <gp_Trsf.hxx>

#include <meshoptimizer.h>

#include <cstdint>
#include <cstdio>
#include <vector>

static int fail(const char* msg) {
  std::fprintf(stderr, "smoke: %s\n", msg);
  return 1;
}

int main() {
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(10.0, 20.0, 30.0).Shape();
  STEPControl_Writer writer;
  if (writer.Transfer(box, STEPControl_AsIs) != IFSelect_RetDone) return fail("step transfer");
  if (writer.Write("/tmp/smoke-box.step") != IFSelect_RetDone) return fail("step write");

  Handle(XCAFApp_Application) app = XCAFApp_Application::GetApplication();
  Handle(TDocStd_Document) doc;
  app->NewDocument("MDTV-XCAF", doc);
  if (doc.IsNull()) return fail("xcaf doc");

  STEPCAFControl_Reader reader;
  if (reader.ReadFile("/tmp/smoke-box.step") != IFSelect_RetDone) return fail("step read");
  if (!reader.Transfer(doc)) return fail("xcaf transfer");

  BRepMesh_IncrementalMesh mesher(box, 0.5);
  if (!mesher.IsDone()) return fail("mesh");

  std::vector<float> pos;
  std::vector<unsigned> idx;
  for (TopExp_Explorer ex(box, TopAbs_FACE); ex.More(); ex.Next()) {
    TopLoc_Location loc;
    Handle(Poly_Triangulation) tri = BRep_Tool::Triangulation(TopoDS::Face(ex.Current()), loc);
    if (tri.IsNull()) continue;
    const gp_Trsf tr = loc.Transformation();
    const int base = static_cast<int>(pos.size() / 3);
    for (int i = 1; i <= tri->NbNodes(); ++i) {
      const gp_Pnt p = tri->Node(i).Transformed(tr);
      pos.push_back(static_cast<float>(p.X()));
      pos.push_back(static_cast<float>(p.Y()));
      pos.push_back(static_cast<float>(p.Z()));
    }
    for (int i = 1; i <= tri->NbTriangles(); ++i) {
      int n1, n2, n3;
      tri->Triangle(i).Get(n1, n2, n3);
      idx.push_back(static_cast<unsigned>(base + n1 - 1));
      idx.push_back(static_cast<unsigned>(base + n2 - 1));
      idx.push_back(static_cast<unsigned>(base + n3 - 1));
    }
  }
  if (idx.size() < 3) return fail("empty mesh");

  std::vector<float> attr(pos.size() / 3 * 3, 0.f);
  const float weights[3] = {1.f, 1.f, 1.f};
  std::vector<unsigned> simplified(idx.size());
  float err = 0.f;
  const size_t kept = meshopt_simplifyWithAttributes(
      simplified.data(), idx.data(), idx.size(), pos.data(), pos.size() / 3, sizeof(float) * 3, attr.data(),
      sizeof(float) * 3, weights, 3, nullptr, idx.size(), 0.01f, 0, &err);
  if (kept == 0) return fail("simplify");

  std::uint8_t rgb[12] = {255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255};
  std::uint8_t* webp = nullptr;
  const size_t bytes = WebPEncodeRGB(rgb, 2, 2, 6, 80.f, &webp);
  if (bytes == 0 || webp == nullptr) return fail("webp");
  WebPFree(webp);
  std::printf("smoke ok tris=%zu kept=%zu webp=%zu\n", idx.size() / 3, kept / 3, bytes);
  return 0;
}
