package layout

import (
	"strings"

	g "github.com/AllenDang/giu"
)

type ProfileLayout struct {
	InputText string
	Layout    *g.Layout
}

func NewProfileLayout() *ProfileLayout {
	l := &ProfileLayout{
		InputText: "",
	}

	l.Layout = &g.Layout{
		g.Row(g.InputText(&l.InputText), g.Button("+").Size(g.Auto, 22).OnClick(l.addProfile)),
		g.Separator(),
	}

	return l
}

func (l *ProfileLayout) addProfile() {
	txt := strings.TrimSpace(l.InputText)
	if txt == "" {
		return
	}

	*l.Layout = append(*l.Layout, g.Row(g.Label(txt)))
	l.InputText = ""
}
