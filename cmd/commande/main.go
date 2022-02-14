//go:generate ../../build.sh --generate-syso
package main

import (
	g "github.com/AllenDang/giu"

	"github.com/rytsh/commande/internal/conf"
	l "github.com/rytsh/commande/internal/layout"
)

var profileLayout = l.NewProfileLayout()
var parserLayout = l.NewParserLayout()

func loop() {
	g.SingleWindow().Layout(
		g.SplitLayout(g.DirectionHorizontal, 200,
			profileLayout.Layout,
			parserLayout.Layout,
		),
	)
}

func main() {
	wnd := g.NewMasterWindow(conf.AppName, 800, 600, 0)
	wnd.Run(loop)
}
