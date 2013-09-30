package application

import java.util.ArrayList
import java.util.concurrent.TimeUnit
import javafx.application.Application
import javafx.application.Platform
import javafx.scene.Scene
import javafx.scene.control.TextField
import javafx.scene.layout.BorderPane
import javafx.scene.layout.GridPane
import javafx.scene.layout.HBox
import javafx.scene.text.Text
import javafx.stage.Stage
import rx.Observable
import rx.Observer
import rx.subjects.BehaviorSubject

import static extension rx.Observable.*

class Main extends Application {
	def static void main(String[] args) {
		launch(args)
	}

	override start(Stage primaryStage) {
		val border = new BorderPane

		val searchExpression = BehaviorSubject.createWithDefaultValue("")

		val searchBox = createSearchBox(searchExpression)
		border.top = searchBox
		
		val resultsPane = createResultsPane(searchExpression)
		border.center = resultsPane
		
		val scene = new Scene(border, 640, 480) => [
		  stylesheets.add(typeof(Main).getResource("style.css").toExternalForm)
		]

		primaryStage.scene = scene
		primaryStage.title = "Hello World!"
		primaryStage.show()
	}

	private def HBox createSearchBox(Observer<String> searchExpression) {
		new HBox => [
			spacing = 10
			id = "search-box"
			children.add(new TextField => [
				id = "search-box-field"
				textProperty.addListener[ control, oldValue, newValue |
					if (newValue != oldValue) {
						searchExpression.onNext(newValue)
					}
				]
			])
		]
	}

	private def GridPane createResultsPane(Observable<String> searchExpression) {
		new GridPane => [
			id = "results-pane"

			val title = new Text("Search results:") => [ id = "search-results-title" ]
			val results = new Text => [ id = "search-results" ]
			val maxSize = 25

			searchExpression
			  .sample(300, TimeUnit.MILLISECONDS)
			  .distinctUntilChanged
			  .map[
			  	Searcher
			  	  .search(it)
			  	  .scan(new ArrayList<String> -> 0)[ acc, next |
			  	  	if (acc.value > maxSize) {
			  	  		acc.key.set(acc.key.length - 1, '''... and «acc.value - maxSize» more''')
			  	  	} else {
			  	  	  acc.key.add(next)
			  	  	}

			  	  	acc.key -> (acc.value + 1)
			  	  ]
			  	  .map[key]
			  	  .map[join("\n")]
			  ]
			  .switchOnNext
			  .subscribe[ Platform.runLater[| results.text = it ] ]

			addRow(0, title)
			addRow(1, results)
		]
	}
}
